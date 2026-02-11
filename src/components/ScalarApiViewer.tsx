import { ApiReferenceReact } from '@scalar/api-reference-react'
import '@scalar/api-reference-react/style.css'

interface Props {
  specUrl: string
  title?: string
}

export default function ScalarApiViewer({ specUrl, title }: Props) {
  return (
    <ApiReferenceReact
      configuration={{
        spec: { url: specUrl },
        theme: 'kepler',
        hideDarkModeToggle: true,
        defaultOpenAllTags: false,
        hideDownloadButton: false,
        metaData: title ? { title } : undefined,
      }}
    />
  )
}
